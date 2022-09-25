using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DialogueInteraction : MonoBehaviour
{
    [SerializeField]
    private LayerMask layerMask;
    private InputHandle inputHandle;
    private DialogueTransform dialogueTransform;

    private void Awake()
    {
        inputHandle = GetComponent<InputHandle>();
        dialogueTransform = FindObjectOfType<DialogueTransform>();
    }

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
                dialogueTransform.SetPosition(colliders[0].transform.position + Vector3.up * 2);
                colliders[0].GetComponent<YarnInteractable>().Interact();
            }
        }
    }
}
