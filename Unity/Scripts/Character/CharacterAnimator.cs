using UnityEngine;

namespace KingdomCome.Character
{
    /// <summary>
    /// 8-direction animator using 4 sprite sheet directions.
    /// Diagonals blend to the nearest cardinal sprite set.
    /// Frame size: 256x256. Assign sprite arrays from sliced sprite sheets.
    /// </summary>
    public class CharacterAnimator : MonoBehaviour
    {
        [Header("Directional Frame Arrays (sliced from sprite sheets)")]
        public Sprite[] framesDown;
        public Sprite[] framesUp;
        public Sprite[] framesLeft;
        public Sprite[] framesRight;

        [Header("Animation")]
        public float frameRate = 8f;

        SpriteRenderer sr;
        Sprite[]        activeFrames;
        int             frameIndex;
        float           timer;
        bool            isMoving;

        // ── 8 directions ─────────────────────────────────────────────────────
        public enum Dir8 { Down, DownRight, Right, UpRight, Up, UpLeft, Left, DownLeft }

        void Awake()
        {
            sr = GetComponent<SpriteRenderer>();
            activeFrames = framesDown;
        }

        /// <summary>Called by SpriteSheetLoader after frames are downloaded.</summary>
        public void ShowIdleFrame()
        {
            activeFrames = framesDown;
            frameIndex   = 0;
            if (activeFrames != null && activeFrames.Length > 0)
                sr.sprite = activeFrames[0];
            Debug.Log($"[CharacterAnimator] Loaded {activeFrames?.Length ?? 0} frames. Sprite shown.");
        }

        /// <summary>Call from PlayerMovement every frame with the input vector.</summary>
        public void SetMovement(Vector2 input)
        {
            isMoving = input.sqrMagnitude > 0.01f;
            if (isMoving) ApplyDirection(ToDir8(input));
        }

        void Update()
        {
            if (!isMoving || activeFrames == null || activeFrames.Length == 0) return;

            timer += Time.deltaTime;
            if (timer < 1f / frameRate) return;
            timer       = 0f;
            frameIndex  = (frameIndex + 1) % activeFrames.Length;
            sr.sprite   = activeFrames[frameIndex];
        }

        // ── Helpers ───────────────────────────────────────────────────────────

        void ApplyDirection(Dir8 dir)
        {
            sr.flipX = false;
            switch (dir)
            {
                case Dir8.Down:
                case Dir8.DownRight:
                case Dir8.DownLeft:
                    SetFrames(framesDown);  break;

                case Dir8.Up:
                case Dir8.UpRight:
                case Dir8.UpLeft:
                    SetFrames(framesUp);    break;

                case Dir8.Right:
                    SetFrames(framesRight); break;

                case Dir8.Left:
                    SetFrames(framesLeft);  break;
            }
        }

        void SetFrames(Sprite[] frames)
        {
            if (frames == activeFrames) return;   // already playing
            activeFrames = frames;
            frameIndex   = 0;
            timer        = 0f;
            if (frames != null && frames.Length > 0)
                sr.sprite = frames[0];
        }

        static Dir8 ToDir8(Vector2 v)
        {
            float angle = Mathf.Atan2(v.y, v.x) * Mathf.Rad2Deg;
            // Normalize to [0, 360)
            if (angle < 0) angle += 360f;

            // 8 sectors of 45° each, starting at East=0°
            // East=Right, North=Up, West=Left, South=Down
            if (angle <  22.5f || angle >= 337.5f) return Dir8.Right;
            if (angle <  67.5f)                    return Dir8.UpRight;
            if (angle < 112.5f)                    return Dir8.Up;
            if (angle < 157.5f)                    return Dir8.UpLeft;
            if (angle < 202.5f)                    return Dir8.Left;
            if (angle < 247.5f)                    return Dir8.DownLeft;
            if (angle < 292.5f)                    return Dir8.Down;
                                                   return Dir8.DownRight;
        }
    }
}
