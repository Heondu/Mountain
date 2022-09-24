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
                Time.timeScale = 0;
                settingsPanel.SetActive(true);
            }
            else
            {
                Time.timeScale = 1;
                settingsPanel.SetActive(false);
            }
        }
    }
}
