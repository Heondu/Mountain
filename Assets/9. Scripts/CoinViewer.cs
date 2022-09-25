using UnityEngine;
using TMPro;

public class CoinViewer : MonoBehaviour
{
    private TextMeshProUGUI text;

    private void Awake()
    {
        text = GetComponent<TextMeshProUGUI>();
        FindObjectOfType<PlayerCoin>().onCoinValueChanged.AddListener(UpdateValue);
    }

    private void UpdateValue(int value)
    {
        text.text = $"{value} x";
    }
}
