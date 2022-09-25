using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class ManaCooldownViewer : MonoBehaviour
{
    private Image image;
    private Mana mana;
    public Mana Mana => mana;

    public UnityEvent onCooldownEnded = new UnityEvent();

    public void Setup(Mana mana)
    {
        this.mana = mana;
        this.mana.onCooldownValueChanged.AddListener(OnCooldownValueChanged);

        image = GetComponent<Image>();
    }

    private void OnCooldownValueChanged(float value)
    {
        image.fillAmount = value;
    }
}
