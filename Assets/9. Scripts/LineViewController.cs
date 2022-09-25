using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Yarn.Unity;

public class LineViewController : MonoBehaviour
{
    [SerializeField]
    private LineView lineView;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Return))
        {
            lineView.OnContinueClicked();
        }
    }
}
