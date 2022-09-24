using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Coin : MonoBehaviour
{
    [SerializeField] private GameObject pickupAudio;
    [SerializeField] private GameObject pickupEffect;

    private void OnTriggerEnter(Collider other)
    {
        PlayerCollisionSphere Player = other.GetComponent<PlayerCollisionSphere>();

        if (!Player)
            return;

        if (pickupAudio)
            Instantiate(pickupAudio, transform.position, Quaternion.identity).GetComponent<PlayAudio>();

        if (pickupEffect)
            Instantiate(pickupEffect, transform.position, Quaternion.identity);

        Player.PlayerMov.GetComponent<PlayerCoin>().AddCoin(1);

        Destroy(gameObject);
    }
}
