"""Attach the two T-pose redrawn heroes to the existing runtime sprite banks.

The PNGs stay byte-identical to their production sources. Landmark inputs are
local to the first cell of the stated row. No pose is resized individually.
Run after the historical registration scripts to restore the redraw entries.
"""

from pathlib import Path
import json
import math

import numpy as np
from PIL import Image

from campaign_registration import match_patch
from register_m1_heroes import grid, isolated, register


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets'
HEROES = {
    'aion': {
        'base': ('c3bd1e24-8a8a-4f40-96dc-c0c5ffcadb5f', (143, 91, 174, 141)),
        'crouch': ('e81a68e2-a545-4c48-933f-f1f3d4afb04e', (247, 167, 278, 240), (1.57, 1.89)),
        'actions': ('2534b75e-9490-4cb2-9879-98fd0835e79a', (144, 89, 168, 138), (1., 1.)),
        'tunnel': ('4da93224-ef8e-4d15-b7e7-4801555d8e1a', (185, 124, 167, 173), (1.02, 1.30)),
        'contact': ('1b2d8e0e-5ffc-4f74-b7a6-1a802b1a4ca7', (225, 137, 262, 217), (1.51, 1.64)),
        'base_hands': [(165, 141), (174, 141), (168, 166), (164, 151), (170, 151)],
        'crouch_hands': [(271, 238), (278, 240)],
        'action_hands': [(168, 138), (168, 144), None, None, (175, 107), (175, 105)],
        'tunnel_hands': [(160, 229), (168, 174), None, (167, 173)],
        'contact_hands': {
            0: [(261, 214), (276, 221), (286, 224), (325, 210), (230, 227), (260, 215)],
            1: [(260, 217), (251, 212), (311, 217), (273, 272), (231, 248), (260, 217)],
        },
        'tunnel_throw': {2: [(171, 177), (93, 157), (80, 138), (216, 170), (163, 173), (155, 176)]},
        'reaction_eyes': {
            4: [(130, 70), (144, 65), (125, 60), (129, 70), (148, 76), (140, 74)],
            5: [(124, 67), (130, 68), (132, 88), (148, 111), (149, 136), (147, 149)],
        },
        'hands': {
            2: [(98, 129), (77, 114), (74, 73), (201, 116), (185, 141), (129, 133)],
            3: [(76, 126), (83, 130), (180, 117), (198, 111), (173, 130), (144, 124)],
            5: [(173, 99), (199, 106), (178, 150), (174, 152), (135, 155), (127, 155)],
        },
    },
    'sheep': {
        'base': ('5fb7f40c-48e8-4f76-a41e-1f0b834c8b99', (133, 93, 156, 144)),
        'crouch': ('fd9aaefa-54ce-4fdc-8e57-bf8a897a609c', (221, 178, 254, 248), (1.70, 2.05)),
        'actions': ('0b5d3a1c-92a4-4a95-b8ab-2b6add1075d6', (145, 96, 158, 146), (.92, 1.12)),
        'tunnel': ('1ab79b27-7545-4149-9c43-ca9427eeb32c', (166, 118, 167, 155), (1.02, 1.34)),
        'contact': ('930c60c3-e517-438e-9114-8245eac84f7e', (211, 145, 238, 222), (1.39, 1.55)),
        'base_hands': [(167, 147), (156, 144), (158, 169), (157, 141), (153, 141)],
        'crouch_hands': [(255, 253), (254, 248)],
        'action_hands': [(160, 143), (150, 151), None, None, (139, 135), (141, 151)],
        'tunnel_hands': [(168, 234), (167, 158), None, (167, 155)],
        'contact_hands': {
            0: [(233, 222), (242, 223), (286, 222), (297, 200), (242, 243), (227, 222)],
            1: [(235, 225), (262, 210), (291, 222), (250, 294), (254, 251), (224, 223)],
        },
        'tunnel_throw': {2: [(168, 154), (86, 149), (78, 126), (229, 154), (149, 156), (163, 155)]},
        'reaction_eyes': {
            4: [(117, 93), (113, 89), (99, 83), (118, 93), (114, 92), (118, 93)],
            5: [(107, 87), (107, 86), (102, 109), (115, 130), (129, 154), (135, 168)],
        },
        'hands': {
            2: [(138, 144), (44, 129), (23, 93), (165, 118), (147, 167), (139, 145)],
            3: [(136, 132), (28, 121), (156, 133), (180, 121), (110, 141), (141, 138)],
            5: [(150, 129), (169, 128), (139, 152), (149, 170), (123, 175), (122, 180)],
        },
    },
}


def fit_scale(patch, marker, base_scale, pixels, atlas, row, landmark, limits):
    """Match one complete neutral face, then use the same scale for the atlas."""
    eye_x, eye_y = landmark[:2]
    neutral = isolated(pixels, atlas['frames'][row][0])
    width = patch.shape[1]
    best = None
    for size in range(round(width * limits[0]), round(width * limits[1]) + 1):
        ratio = size / width
        template = np.asarray(Image.fromarray(patch).resize(
            (size, round(patch.shape[0] * ratio)), Image.Resampling.NEAREST))
        _, _, error = match_patch(neutral, template,
                                 [eye_x-marker[0]*ratio, eye_y-marker[1]*ratio], [9, 9])
        if best is None or error < best[0]:
            best = (error, ratio)
    return base_scale / best[1], best[1], best[0]


def solid_hand(cel, hand):
    """Small correction only when the reviewed hand falls on its alpha fringe."""
    x, y = (round(v) for v in hand)
    xs = range(max(0, x-9), min(cel.shape[1], x+10))
    ys = range(max(0, y-9), min(cel.shape[0], y+10))
    candidates = [(px, py) for py in ys for px in xs if cel[py, px, 3] >= 192]
    if not candidates:
        raise ValueError(f'No opaque body at the hand landmark {hand}')
    return list(min(candidates, key=lambda point: (point[0]-x)**2+(point[1]-y)**2))


def register_hands(pixels, atlas, row_hands, overrides=None):
    for row, frames in enumerate(atlas['frames']):
        first = frames[0]
        start = np.array(first['face_landmark'])
        manual = overrides and row in overrides
        if not manual:
            neutral = isolated(pixels, first)
            x, y = solid_hand(neutral, row_hands[row])
            left, top = max(0, x-9), max(0, y-9)
            patch = neutral[top:y+10, left:x+10]
        for col, cel in enumerate(frames):
            body = isolated(pixels, cel)
            cel.pop('grip_patch', None)
            cel.pop('grip_residual', None)
            if manual:
                hand = overrides[row][col]
                cel['grip_method'] = 'reviewed wrist or knuckle per cel'
            else:
                shift = np.array(cel['face_landmark']) - start
                px, py, error = match_patch(body, patch, np.array([left, top]) + shift, [14, 14])
                if not math.isfinite(error):
                    raise ValueError(f'{atlas["path"]}, row {row}, cel {col}: no wrist match')
                hand = (px+x-left, py+y-top)
                cel['grip_patch'] = [px, py, patch.shape[1], patch.shape[0]]
                cel['grip_residual'] = round(error, 6)
                cel['grip_method'] = 'reviewed row-neutral wrist with bounded patch tracking'
            try:
                cel['grip'] = solid_hand(body, hand)
            except ValueError as error:
                raise ValueError(f'{atlas["path"]}, row {row}, cel {col}: {error}') from error
            cel['grenade_embedded'] = False


def register_reaction_faces(atlas, eyes):
    for row, landmarks in eyes.items():
        for cel, eye in zip(atlas['frames'][row], landmarks, strict=True):
            cel['face_landmark'] = list(eye)
            cel['origin'][0] = eye[0] - 14.0 / cel['scale']
            cel['face_reference_width'] = cel.pop('face_patch')[2]
            cel.pop('face_residual', None)
            cel['registration'] = 'reviewed eye or eyelid and connected sole'


def save_json(path, data):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':'), allow_nan=False) + '\n')
    temporary.replace(path)


def main():
    base_path = ASSETS / 'M1-HEROES-PROVENANCE.json'
    actions_path = ASSETS / 'M1-HERO-ACTIONS.json'
    base = json.loads(base_path.read_text())
    actions = json.loads(actions_path.read_text())
    reference_heights = base.setdefault('redraw_reference_heights', {})
    for hero, source in HEROES.items():
        original = base['atlases'][hero]['frames'][1][0]
        target = reference_heights.setdefault(hero, (original['body_bounds'][3]-original['body_bounds'][1])*original['scale'])
        file = ASSETS / f'm1-redraw-{hero}.png'
        pixels, redraw = grid(file, 5)
        top, bottom = redraw['frames'][1][0]['body_bounds'][1::2]
        scale = target / (bottom-top)
        patch, marker = register(pixels, redraw, hero, range(5), 1, source['base'][1], scale)
        register_hands(pixels, redraw, source['base_hands'])
        redraw['runtime_rows'] = [0, 1, 2]
        redraw['calibration'][hero]['reference'] = 'T-pose silhouette and existing registered standing world height'
        base['atlases'][hero] = redraw
        base['generation_sources'][file.name] = 'exec-' + source['base'][0]

        for kind, rows, neutral_row in [('crouch', 2, 1), ('actions', 6, 0), ('tunnel', 4, 3), ('contact', 2, 0)]:
            generation, landmark, limits = source[kind]
            file = ASSETS / f'm1-redraw-{hero}-{kind}.png'
            pixels, atlas = grid(file, rows)
            fitted_scale, ratio, error = fit_scale(patch, marker, scale, pixels, atlas, neutral_row, landmark, limits)
            register(pixels, atlas, hero, range(rows), neutral_row, landmark, fitted_scale, ratio=ratio)
            if kind == 'actions':
                register_reaction_faces(atlas, source['reaction_eyes'])
            hand_rows = source[('action' if kind == 'actions' else kind) + '_hands']
            overrides = {'actions': source['hands'], 'tunnel': source['tunnel_throw'],
                         'contact': source['contact_hands']}.get(kind)
            register_hands(pixels, atlas, hand_rows, overrides)
            atlas['calibration'][hero]['neutral_fit_error'] = error
            bank = base if kind == 'crouch' else actions
            bank['generation_sources'][file.name] = 'exec-' + generation
            if kind == 'crouch':
                atlas['runtime_rows'] = [0, 1]
                bank['atlases'][hero+'_crouch'] = atlas
            elif kind == 'actions':
                atlas['runtime_rows'] = list(range(6))
                bank['atlases'][hero+'_redraw'] = atlas
            elif kind == 'tunnel':
                max_height = max((cel['origin'][1]-cel['bounds'][1])*fitted_scale
                                 for row in atlas['frames'] for cel in row)
                assert max_height <= 54.5, (hero, 'tunnel clearance including draw rounding', max_height)
                atlas['calibration'][hero]['max_visible_height'] = max_height
                atlas['runtime_rows'] = list(range(4))
                bank['atlases'][hero+'_tunnel'] = atlas
            else:
                atlas['runtime_rows'] = [0, 1]
                bank['atlases'][hero+'_contact'] = atlas

    base['redrawn_heroes'] = list(HEROES)
    for hero in HEROES:
        old_tunnel = base['atlases'].pop(hero+'_tunnel', {})
        if old_tunnel:
            base['generation_sources'].pop(Path(old_tunnel['path']).name, None)
    actions['redrawn_heroes'] = list(HEROES)
    actions['redraw_rows'] = {'walk_back': 0, 'crouch_walk_back': 1, 'grenade_throw': 2,
                              'crouch_grenade_throw': 3, 'hurt': 4, 'death': 5}
    actions['playback'].update({'hurt': {'frames': 6, 'seconds': .3, 'loop': False},
                                'death': {'frames': 6, 'seconds': .8, 'loop': False},
                                'melee': {'frames': 6, 'seconds': .28, 'loop': False},
                                'rescue_cut': {'frames': 6, 'seconds': .6, 'loop': False}})
    save_json(base_path, base)
    save_json(actions_path, actions)
    print('Registered ten source atlases for Aion and Kutsanmış.')


if __name__ == '__main__':
    main()
