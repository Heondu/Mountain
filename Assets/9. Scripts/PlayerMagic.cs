using UnityEngine;

public class PlayerMagic : MonoBehaviour
{
    [SerializeField] private float magicRadius = 5;
    [SerializeField] private int manaCost = 1;
    [SerializeField] private LayerMask plantLayer;

    private PlayerMana playerMana;

    private void Awake()
    {
        playerMana = GetComponent<PlayerMana>();
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            if (playerMana.Use(manaCost))
            {
                PlantTree();
            }
        }
    }

    private void PlantTree()
    {
        Collider[] colliders = Physics.OverlapSphere(transform.position, magicRadius, plantLayer);
        foreach (Collider c in colliders)
        {
            c.GetComponent<PlantGrower>().Grow();
        }
    }
}
