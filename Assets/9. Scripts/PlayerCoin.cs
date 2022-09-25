using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class PlayerCoin : MonoBehaviour
{
    private int coinNum = 0;

    [HideInInspector] public UnityEvent<int> onCoinValueChanged = new UnityEvent<int>();

    public void AddCoin(int num)
    {
        coinNum += num;
        UIUpdate();
    }

    private void UIUpdate()
    {
        onCoinValueChanged.Invoke(coinNum);
    }
}
