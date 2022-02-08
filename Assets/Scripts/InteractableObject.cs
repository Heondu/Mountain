using UnityEngine;
using UnityEngine.Events;

public class InteractableObject : MonoBehaviour
{
    public UnityEvent onActivate = new UnityEvent();
    public UnityEvent onDeactivate = new UnityEvent();
    public UnityEvent onInteract = new UnityEvent();

    private Outline[] outlines;
    private bool isActive;
    public bool IsActive => isActive;

    protected virtual void Awake()
    {
        outlines = GetComponentsInChildren<Outline>();
        for (int i = 0; i < outlines.Length; i++)
        {
            outlines[i].Deactivate();
            onActivate.AddListener(outlines[i].Activate);
            onDeactivate.AddListener(outlines[i].Deactivate);
        }
    }

    public void Activate()
    {
        onActivate.Invoke();
        isActive = true;
    }

    public void Deactivate()
    {
        onDeactivate.Invoke();
        isActive = false;
    }

    public void Interact()
    {
        onInteract.Invoke();
    }
}
