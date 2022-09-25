using UnityEngine;

public class UIManager : MonoBehaviour
{
    [SerializeField]
    private GameObject settingsPanel;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (!settingsPanel.activeSelf)
            {
                OpenSettingsPanel();
            }
            else
            {
                CloseSettingsPanel();
            }
        }
    }

    public void OpenSettingsPanel()
    {
        Time.timeScale = 0;
        settingsPanel.SetActive(true);
    }

    public void CloseSettingsPanel()
    {
        Time.timeScale = 1;
        settingsPanel.SetActive(false);
    }
}
