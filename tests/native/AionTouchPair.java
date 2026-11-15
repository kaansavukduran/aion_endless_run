/** Ordinary two-finger Android gesture injector used by emulator QA.
 * It only injects touchscreen events; it cannot read or set game state.
 */
public final class AionTouchPair {
    private static Object manager;
    private static java.lang.reflect.Method inject;
    private static long down;

    private static void send(int action, int count, int[] xs, int[] ys) throws Exception {
        android.view.MotionEvent.PointerProperties[] properties = new android.view.MotionEvent.PointerProperties[count];
        android.view.MotionEvent.PointerCoords[] coordinates = new android.view.MotionEvent.PointerCoords[count];
        for (int i = 0; i < count; i++) {
            properties[i] = new android.view.MotionEvent.PointerProperties();
            properties[i].id = i;
            properties[i].toolType = android.view.MotionEvent.TOOL_TYPE_FINGER;
            coordinates[i] = new android.view.MotionEvent.PointerCoords();
            coordinates[i].x = xs[i]; coordinates[i].y = ys[i];
            coordinates[i].pressure = 1; coordinates[i].size = .02f;
        }
        android.view.MotionEvent event = android.view.MotionEvent.obtain(down,
            android.os.SystemClock.uptimeMillis(), action, count, properties, coordinates,
            0, 0, 1, 1, 0, 0, android.view.InputDevice.SOURCE_TOUCHSCREEN, 0);
        try {
            if (!((Boolean) inject.invoke(manager, event, 2)))
                throw new IllegalStateException("Touch injection rejected");
        } finally { event.recycle(); }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 5) throw new IllegalArgumentException("x1 y1 x2 y2 duration_ms required");
        int[] xs = {Integer.parseInt(args[0]), Integer.parseInt(args[2])};
        int[] ys = {Integer.parseInt(args[1]), Integer.parseInt(args[3])};
        int duration = Integer.parseInt(args[4]);
        if (xs[0] < 0 || xs[1] < 0 || ys[0] < 0 || ys[1] < 0 || duration < 100 || duration > 10000)
            throw new IllegalArgumentException("Invalid touch coordinates or duration");
        Class<?> type = Class.forName("android.hardware.input.InputManager");
        manager = type.getMethod("getInstance").invoke(null);
        inject = type.getMethod("injectInputEvent", android.view.InputEvent.class, int.class);
        down = android.os.SystemClock.uptimeMillis();
        send(android.view.MotionEvent.ACTION_DOWN, 1, xs, ys);
        Thread.sleep(30);
        send(android.view.MotionEvent.ACTION_POINTER_DOWN | (1 << android.view.MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, xs, ys);
        long until = android.os.SystemClock.uptimeMillis() + duration;
        while (android.os.SystemClock.uptimeMillis() < until) {
            send(android.view.MotionEvent.ACTION_MOVE, 2, xs, ys);
            Thread.sleep(25);
        }
        send(android.view.MotionEvent.ACTION_POINTER_UP | (1 << android.view.MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, xs, ys);
        Thread.sleep(30);
        send(android.view.MotionEvent.ACTION_UP, 1, xs, ys);
        System.out.println("AION_ADB_TWO_TOUCH duration_ms=" + duration + " contacts=2 released=true");
    }
}
