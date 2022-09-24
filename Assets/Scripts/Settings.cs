using UnityEngine;
using UnityEngine.Audio;

public class Settings : MonoBehaviour
{
    [SerializeField]
    private AudioMixer audioMixer;

    public void SetBGMVolume(float value)
    {
        if (value == -40f) audioMixer.SetFloat("BGM", -80);
        else audioMixer.SetFloat("BGM", value);
    }

    public void SetSFXVolume(float value)
    {
        if (value == -40f) audioMixer.SetFloat("SFX", -80);
        else audioMixer.SetFloat("SFX", value);
    }

    public void QuitGame()
    {
        Application.Quit();
    }
}
