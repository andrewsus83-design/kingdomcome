using UnityEngine;

namespace KingdomCome.Character
{
    /// <summary>
    /// Top-down 8-direction player movement.
    /// Requires: Rigidbody2D, CharacterAnimator on same GameObject.
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D))]
    [RequireComponent(typeof(CharacterAnimator))]
    public class PlayerMovement : MonoBehaviour
    {
        [Header("Movement")]
        public float moveSpeed = 5f;

        Rigidbody2D      rb;
        CharacterAnimator anim;
        Vector2           input;

        void Awake()
        {
            rb   = GetComponent<Rigidbody2D>();
            anim = GetComponent<CharacterAnimator>();

            rb.gravityScale = 0f;
            rb.constraints  = RigidbodyConstraints2D.FreezeRotation;
        }

        void Update()
        {
            input = new Vector2(
                Input.GetAxisRaw("Horizontal"),
                Input.GetAxisRaw("Vertical")
            ).normalized;

            anim.SetMovement(input);
        }

        void FixedUpdate()
        {
            rb.linearVelocity = input * moveSpeed;
        }
    }
}
