"""Configure local Godot credentials from environment; never print or commit them."""
import os
from pathlib import Path

config_dir = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
config_dir.mkdir(parents=True, exist_ok=True)
def escaped(value):
    return str(value).replace("\\", "/").replace('"', '\\"')

(config_dir / "editor_settings-4.6.tres").write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    f'export/android/java_sdk_path = "{escaped(os.environ["JAVA_HOME"])}"\n'
    f'export/android/android_sdk_path = "{escaped(os.environ["ANDROID_HOME"])}"\n'
)
credentials = Path(".godot/export_credentials.cfg")
credentials.parent.mkdir(exist_ok=True)
credentials.write_text(
    '[preset.4.options]\n'
    f'keystore/release="{escaped(os.environ["AION_KEYSTORE"])}"\n'
    f'keystore/release_user="{escaped(os.environ["AION_KEY_ALIAS"])}"\n'
    f'keystore/release_password="{escaped(os.environ["AION_KEY_PASSWORD"])}"\n'
)
credentials.chmod(0o600)
