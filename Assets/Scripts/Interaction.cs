using UnityEngine;

public class Interaction : MonoBehaviour
{
    [SerializeField] private float interactionRaidus;
    [SerializeField] private LayerMask interactionLayer;

    private InteractableObject interactableObj;

    private void Update()
    {
        CheckForPickupableObj();
        InputInteraction();
    }

    private void CheckForPickupableObj()
    {
        Collider[] colliders = Physics.OverlapSphere(transform.position, interactionRaidus, interactionLayer);
        InteractableObject closestObj = null;
        float closestDistance = float.MaxValue;
        foreach (Collider c in colliders)
        {
            float distance = Vector3.SqrMagnitude(transform.position - c.transform.position);
            if (closestDistance > distance)
            {
                closestObj = c.GetComponent<InteractableObject>();
                closestDistance = distance;
            }
        }

        if (closestObj == null)
        {
            DeactivatePickupableObj();
        }
        if (closestObj != null && !closestObj.IsActive)
        {
            DeactivatePickupableObj();
            interactableObj = closestObj;
            ActivatePickupableObj();
        }
    }

    private void ActivatePickupableObj()
    {
        if (interactableObj == null)
            return;

        interactableObj.Activate();
    }

    private void DeactivatePickupableObj()
    {
        if (interactableObj == null)
            return;

        interactableObj.Deactivate();
        interactableObj = null;
    }

    private void InputInteraction()
    {
        if (interactableObj == null)
            return;

        if (Input.GetKeyDown(KeyCode.E))
            interactableObj.Interact();
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, interactionRaidus);
    }
}
