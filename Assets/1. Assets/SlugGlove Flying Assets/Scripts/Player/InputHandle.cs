using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputHandle : MonoBehaviour
{
    private PlayerFlyingGauge playerFlyingGauge;

    public float Horizontal;
    public float Vertical;

    public bool Jump;
    public bool JumpHold;

    public bool Accelerate;

    public bool LB;
    public bool RB;

    public bool Fly;
    public bool Dash;

    public bool isStop = false;

    private void Start()
    {
        playerFlyingGauge = GetComponent<PlayerFlyingGauge>();
    }

    // Update is called once per frame
    void Update()
    {
        if (isStop)
        {
            Horizontal = 0;
            Vertical = 0;
            Jump = false;
            JumpHold = false;
            Fly = false;
            Dash = false;
            RB = false;
            LB = false;
            return;
        }

        Horizontal = Input.GetAxis("Horizontal");
        Vertical = Input.GetAxis("Vertical");

        Jump = Input.GetButtonDown("Jump");
        JumpHold = Input.GetButton("Jump");
        Fly = (JumpHold && playerFlyingGauge.isGaugeLeft()) ? true : false;
        Dash = Input.GetButton("Dash");

        RB = Input.GetKey(KeyCode.E);
        LB = Input.GetKey(KeyCode.Q);
    }

    public void Stop(bool value)
    {
        isStop = value;
    }
}
