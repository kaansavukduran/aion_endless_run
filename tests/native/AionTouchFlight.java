/** Test driver: four complete Android input gestures in one shell VM.
 * Does not access app internals, files, health, scores, RNG or physics.
 */
public final class AionTouchFlight {
    public static void main(String[] args) throws Exception {
        if (args.length != 2) throw new IllegalArgumentException("x y required");
        int x = Integer.parseInt(args[0]), y = Integer.parseInt(args[1]);
        if (x < 0 || y < 0) throw new IllegalArgumentException("negative position");
        java.lang.reflect.Method input = Class.forName("com.android.commands.input.Input")
            .getMethod("main", String[].class);
        int[] durations = {900, 650, 650, 650};
        for (int i = 0; i < durations.length; i++) {
            long started = System.nanoTime();
            String[] gesture = {"touchscreen", "swipe", String.valueOf(x), String.valueOf(y),
                String.valueOf(x), String.valueOf(y), String.valueOf(durations[i])};
            input.invoke(null, (Object) gesture);
            System.out.println("AION_ADB_CONTACT " + i + " duration_ms=" +
                ((System.nanoTime() - started) / 1000000));
            if (i < durations.length - 1) Thread.sleep(60);
        }
    }
}
