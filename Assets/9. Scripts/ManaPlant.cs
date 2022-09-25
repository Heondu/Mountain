public class ManaPlant : InteractableObject
{
    protected override void Awake()
    {
        base.Awake();

        onInteract.AddListener(FindObjectOfType<PlayerMana>().Add);
        onInteract.AddListener(Destroy);
    }

    private void Destroy()
    {
        Destroy(gameObject);
    }
}
