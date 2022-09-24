using UnityEngine;

public class Feather : MonoBehaviour
{
    [SerializeField] private float flyingGaugeAmount = 5f;
    [SerializeField] private GameObject featherAudio;

    private void OnTriggerEnter(Collider other)
    {
        PlayerCollisionSphere Player = other.GetComponent<PlayerCollisionSphere>();

        if (!Player)
            return;

        Player.PlayerMov.GetComponent<PlayerFlyingGauge>().AddFlyingGauge(flyingGaugeAmount);

        Instantiate(featherAudio, transform.position, Quaternion.identity).GetComponent<PlayAudio>();

        Destroy(gameObject);
    }
}
