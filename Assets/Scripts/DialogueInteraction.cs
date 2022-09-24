using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DialogueInteraction : MonoBehaviour
{
    [SerializeField]
    private LayerMask layerMask;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.E))
        {
            Collider[] colliders = Physics.OverlapSphere(transform.position, 5f, layerMask);
            foreach (Collider col in colliders)
            {
                Debug.Log(col.name);
            }
            if (colliders != null)
            {
                colliders[0].GetComponent<YarnInteractable>().Interact();
            }
        }
    }
}
