using UnityEngine;

public class PlantGrower : MonoBehaviour
{
    private Animator animator;

    private void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void Grow()
    {
        animator.SetTrigger("onGrow");
        enabled = false;
    }
}
