using UnityEngine;
using UnityEngine.Events;

public class PlayerFlyingGauge : MonoBehaviour
{
    [SerializeField] private float flyingGauge = 5f;
    private float currentFlyingGauge = 0f;
    [SerializeField] private float cooldown = 3f;
    private PlayerMovement movement;
    private int featherNum = 0;
    private InputHandle inputHand;

    [HideInInspector]
    public UnityEvent<float, float> onGaugeValueChanged = new UnityEvent<float, float>();
    public UnityEvent<int> onFeatherValueChanged = new UnityEvent<int>();

    private void Awake()
    {
        movement = GetComponent<PlayerMovement>();
        inputHand = GetComponent<InputHandle>();
        currentFlyingGauge = flyingGauge;
    }

    private void Update()
    {
        if (movement.States == PlayerMovement.WorldState.Grounded)
            Cooldown();
        else if (movement.States == PlayerMovement.WorldState.Flying)
        {
            if (inputHand.Fly)
                UseGauge();
        }
    }

    public void AddFlyingGauge(float amount)
    {
        featherNum++;
        flyingGauge += amount;
        GaugeUIUpdate();
    }

    private void Cooldown()
    {
        currentFlyingGauge += Time.deltaTime * (flyingGauge / cooldown);
        ClampGauge();
        GaugeUIUpdate();
    }

    private void UseGauge()
    {
        currentFlyingGauge -= Time.deltaTime;
        ClampGauge();
        GaugeUIUpdate();
    }

    public bool isGaugeLeft()
    {
        if (currentFlyingGauge <= 0)
            return false;
        return true;
    }

    private void GaugeUIUpdate()
    {
        onGaugeValueChanged.Invoke(flyingGauge, currentFlyingGauge);
        onFeatherValueChanged.Invoke(featherNum);
    }

    private void ClampGauge()
    {
        currentFlyingGauge = Mathf.Clamp(currentFlyingGauge, 0, flyingGauge);
    }
}
