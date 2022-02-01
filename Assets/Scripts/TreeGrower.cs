using UnityEngine;

public class TreeGrower : MonoBehaviour
{
    private Animator animator;
    private bool isGrow = false;

    private void Awake()
    {
        animator = GetComponent<Animator>();
    }

    private void OnTriggerStay(Collider other)
    {
        Debug.Log(other.name);
        if (!other.CompareTag("Player"))
            return;
        if (isGrow)
            return;

        if (Input.GetKeyDown(KeyCode.E))
        {
            isGrow = true;
            animator.SetTrigger("onGrow");
        }
    }
}
