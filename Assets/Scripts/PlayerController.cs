using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private float speed = 5f;
    [SerializeField] private float jumpHeight = 2f;
    [SerializeField] private float groundDistance = 0.2f;
    [SerializeField] private float dashDistance = 5f;
    [SerializeField] private LayerMask ground;
    [SerializeField] private Transform groundChecker;

    private new Rigidbody rigidbody;
    private Vector3 inputs = Vector3.zero;
    private bool isGrounded = true;

    private void Awake()
    {
        rigidbody = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        GroundCheck();
        GetAxis();
        RotateUpdate();
        JumpUpdate();
    }

    private void FixedUpdate()
    {
        Move();
    }

    private void GroundCheck()
    {
        isGrounded = Physics.CheckSphere(groundChecker.position, groundDistance, ground, QueryTriggerInteraction.Ignore);
    }

    private void GetAxis()
    {
        inputs = Vector3.zero;
        inputs.x = Input.GetAxis("Horizontal");
        inputs.z = Input.GetAxis("Vertical");
    }

    private void RotateUpdate()
    {
        if (inputs != Vector3.zero)
            Rotate();
    }

    private void Rotate()
    {
        transform.forward = inputs;
    }

    private void Move()
    {
        rigidbody.MovePosition(rigidbody.position + inputs.normalized * speed * Time.fixedDeltaTime);
    }

    private void JumpUpdate()
    {
        if (Input.GetButtonDown("Jump") && isGrounded)
            Jump();
    }

    private void Jump()
    {
        rigidbody.AddForce(Vector3.up * Mathf.Sqrt(jumpHeight * -2f * Physics.gravity.y), ForceMode.VelocityChange);
    }
}