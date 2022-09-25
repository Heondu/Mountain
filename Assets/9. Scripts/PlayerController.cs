using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private float speed = 5f;
    [SerializeField] private float dashMod = 1.5f;
    [SerializeField] private float rotateSpeed = 10;
    [SerializeField] private float jumpHeight = 2f;
    [SerializeField] private float groundDistance = 0.2f;
    [SerializeField] private LayerMask ground;
    [SerializeField] private Transform groundChecker;

    private new Rigidbody rigidbody;
    private PlantSpawner plantSpawner;
    
    private Vector3 inputs = Vector3.zero;
    private Vector3 direction = Vector3.zero;
    private bool isGrounded = true;
    

    private void Awake()
    {
        rigidbody = GetComponent<Rigidbody>();
        plantSpawner = GetComponent<PlantSpawner>();
    }

    private void Update()
    {
        GetInputAxis();
        InputToDirection();

        RotateUpdate();

        GroundCheck();
        JumpUpdate();
    }

    private void FixedUpdate()
    {
        MoveUpdate();
    }

    private void GroundCheck()
    {
        isGrounded = Physics.CheckSphere(groundChecker.position, groundDistance, ground, QueryTriggerInteraction.Ignore);
    }

    private void GetInputAxis()
    {
        inputs = Vector3.zero;
        inputs.x = Input.GetAxis("Horizontal");
        inputs.z = Input.GetAxis("Vertical");
    }

    private void InputToDirection()
    {
        Vector3 forward = Camera.main.transform.forward;
        Vector3 right = Camera.main.transform.right;

        forward.y = 0;
        right.y = 0;
        forward.Normalize();
        right.Normalize();

        direction = forward * inputs.z + right * inputs.x;
    }

    private void RotateUpdate()
    {
        if (inputs != Vector3.zero)
            Rotate();
    }

    private void Rotate()
    {
        transform.forward = Vector3.Slerp(transform.forward, direction, Time.deltaTime * rotateSpeed);
    }

    private void MoveUpdate()
    {
        if (inputs != Vector3.zero)
        {
            Move();
            SpawnPlant();
        }
    }

    private void SpawnPlant()
    {
        if (isGrounded)
            plantSpawner.SpawnPlant(transform.position, Quaternion.identity);
    }

    private void Move()
    {
        float speed = Input.GetKey(KeyCode.LeftShift) ? this.speed * dashMod : this.speed;
        rigidbody.MovePosition(rigidbody.position + direction.normalized * speed * Time.fixedDeltaTime);
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