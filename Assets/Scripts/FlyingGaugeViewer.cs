using UnityEngine;
using UnityEngine.UI;

public class FlyingGaugeViewer : MonoBehaviour
{
    private Slider slider;

    private void Awake()
    {
        slider = GetComponent<Slider>();
        FindObjectOfType<PlayerFlyingGauge>().onValueChanged.AddListener(UpdateValue);
    }

    private void UpdateValue(float max, float current)
    {
        slider.value = current / max;
    }
}
