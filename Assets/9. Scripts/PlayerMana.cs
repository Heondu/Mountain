using System.Collections.Generic;
using System.Collections;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;

public class Mana
{
    public bool isCooldown = false;
    public float currentCooldown = 0;
    public UnityEvent<float> onCooldownValueChanged = new UnityEvent<float>();
}

public class PlayerMana : MonoBehaviour
{
    [SerializeField] private float cooldown = 1;

    private List<Mana> manaList = new List<Mana>();

    public UnityEvent<Mana> onAddingMana = new UnityEvent<Mana>();

    public void Add()
    {
        Mana mana = new Mana();
        manaList.Add(mana);
        onAddingMana.Invoke(mana);
    }

    public bool Use(int num)
    {
        List<Mana> availableMana = new List<Mana>();
        for (int i = manaList.Count - 1; i >= 0; i--)
        {
            if (!manaList[i].isCooldown)
                availableMana.Add(manaList[i]);
        }
        if (availableMana.Count < num)
            return false;

        for (int i = 0; i < num; i++)
        {
            StartCoroutine("Cooldown", availableMana[i]);
        }

        return true;
    }

    private IEnumerator Cooldown(Mana mana)
    {
        mana.isCooldown = true;
        mana.currentCooldown = cooldown;
        while (mana.currentCooldown > 0)
        {
            mana.currentCooldown -= Time.deltaTime;
            mana.onCooldownValueChanged.Invoke(mana.currentCooldown / cooldown);
            yield return null;
        }
        mana.currentCooldown = 0;
        mana.isCooldown = false;
    }
}
