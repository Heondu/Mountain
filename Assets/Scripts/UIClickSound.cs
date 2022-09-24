using UnityEngine;

public class UIClickSound : MonoBehaviour
{
    [SerializeField]
    private AudioSource audioSource;

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            audioSource.Play();
        }
    }
}
