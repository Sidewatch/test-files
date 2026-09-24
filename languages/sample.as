package com.example.game {
    import flash.display.Sprite;
    import flash.events.Event;

    /** A ball that bounces inside the stage. */
    public class Ball extends Sprite {
        private var vx:Number = 3.5;
        private var vy:Number = -2;
        public static const RADIUS:int = 12;

        public function Ball(color:uint = 0xFF6600) {
            graphics.beginFill(color);
            graphics.drawCircle(0, 0, RADIUS);
            graphics.endFill();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        private function onFrame(e:Event):void {
            x += vx; y += vy;
            if (x < RADIUS || x > stage.stageWidth - RADIUS) vx *= -1;   // bounce
            if (y < RADIUS || y > stage.stageHeight - RADIUS) vy *= -1;
            trace("ball at", x.toFixed(1), y.toFixed(1));
        }
    }
}
