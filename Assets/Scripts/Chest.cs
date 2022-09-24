using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chest : MonoBehaviour
{
    [SerializeField] private Animator chestAnimator;
    [SerializeField] private GameObject fx;
    [SerializeField] private GameObject sfx;
    [SerializeField] private GameObject coin;
    [SerializeField] private int coinNum;

    private bool isOpen = false;

    private void OnTriggerEnter(Collider other)
    {
        PlayerCollisionSphere Player = other.GetComponent<PlayerCollisionSphere>();

        if (!Player)
            return;

        if (isOpen)
            return;

        isOpen = true;

        chestAnimator.SetBool("isOpen", true);

        if (fx)
            Instantiate(fx, transform.position + Vector3.up * 2, Quaternion.identity);

        if (sfx)
            Instantiate(fx, transform.position, Quaternion.identity);

        SpawnCoin();
    }

    private void SpawnCoin()
    {
        if (!coin)
            return;

        for (int i = 0; i < coinNum; i++)
        {
            Vector3 randomPos = new Vector3(Random.Range(-0.5f, 0.5f), 0.5f, Random.Range(-0.5f, 0.5f));
            Rigidbody clone = Instantiate(coin, transform.position + randomPos, Quaternion.identity).GetComponent<Rigidbody>();
            clone.AddExplosionForce(400, transform.position, 10, 10);
        }
    }
}
