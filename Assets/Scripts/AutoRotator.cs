using UnityEngine;

public class AutoRotator : MonoBehaviour
{
    [SerializeField] private Vector3 direction;
    [SerializeField] private float speed = 10;

    private void Update()
    {
        transform.Rotate(direction * speed * Time.deltaTime);
    }
}
