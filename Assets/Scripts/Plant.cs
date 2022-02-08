using UnityEngine;

public class Plant : MonoBehaviour, IPooledObject
{
    [SerializeField] private float lifetime = 1;

    private Animator animator;

    private void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void OnObjectSpawn()
    {
        animator.SetTrigger("onGrow");

        Invoke("Deactivate", lifetime);
    }

    private void Deactivate()
    {
        animator.SetTrigger("onWither");
    }
}
