using UnityEngine;

public class Feather : MonoBehaviour
{
    [SerializeField] private float flyingGaugeAmount = 5f;

    private void OnTriggerEnter(Collider other)
    {
        PlayerCollisionSphere Player = other.GetComponent<PlayerCollisionSphere>();

        if (!Player)
            return;

        Player.PlayerMov.GetComponent<PlayerFlyingGauge>().AddFlyingGauge(flyingGaugeAmount);
        Destroy(gameObject);
    }
}
