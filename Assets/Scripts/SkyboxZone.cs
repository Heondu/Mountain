using UnityEngine;

public class SkyboxZone : MonoBehaviour
{
    [SerializeField]
    private Material enterSky;
    [SerializeField]
    private Color enterFog;
    [SerializeField]
    private Material exitSky;
    [SerializeField]
    private Color exitFog;

    private void OnTriggerEnter(Collider other)
    {
        if (enterSky == null) return;

        if (other.gameObject.CompareTag("Player"))
        {
            RenderSettings.skybox = enterSky;
            RenderSettings.fogColor = enterFog;
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (exitSky == null) return;

        if (other.gameObject.CompareTag("Player"))
        {
            RenderSettings.skybox = exitSky;
            RenderSettings.fogColor = exitFog;
        }
    }
}
