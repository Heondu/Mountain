using UnityEngine;
using UnityEngine.UI;

public class ManaViewer : MonoBehaviour
{
    [SerializeField] private Image manaImagePrefab;
    [SerializeField] private Transform manaImageHolder;
    [SerializeField] private PlayerMana playerMana;


    private void Awake()
    {
        playerMana.onAddingMana.AddListener(UpdateStatus);
    }

    private void UpdateStatus(Mana mana)
    {
        Image clone = Instantiate(manaImagePrefab, Vector3.zero, Quaternion.identity, manaImageHolder);

        ManaCooldownViewer cooldownViewer = clone.GetComponentInChildren<ManaCooldownViewer>();
        cooldownViewer.Setup(mana);
    }
}
