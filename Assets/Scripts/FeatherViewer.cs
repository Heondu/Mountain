using UnityEngine;
using TMPro;

public class FeatherViewer : MonoBehaviour
{
    private TextMeshProUGUI text;

    private void Awake()
    {
        text = GetComponent<TextMeshProUGUI>();
        FindObjectOfType<PlayerFlyingGauge>().onFeatherValueChanged.AddListener(UpdateValue);
    }

    private void UpdateValue(int value)
    {
        text.text = $"x {value}";
    }
}
