using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputHandle : MonoBehaviour
{
    private PlayerMovement Player;

    public float Horizontal;
    public float Vertical;

    public bool Jump;
    public bool JumpHold;

    public bool Accelerate;

    public bool LB;
    public bool RB;

    public bool Fly;
    public bool Dash;

    private void Start()
    {
        Player = GetComponent<PlayerMovement>();
    }

    // Update is called once per frame
    void Update()
    {
        Horizontal = Input.GetAxis("Horizontal");
        Vertical = Input.GetAxis("Vertical");

        Jump = Input.GetButtonDown("Jump");
        JumpHold = Input.GetButton("Jump");
        Fly = JumpHold;
        Dash = Input.GetButton("Dash");

        RB = Input.GetKey(KeyCode.E);
        LB = Input.GetKey(KeyCode.Q);
    }
}
