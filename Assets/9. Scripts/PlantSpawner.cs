using UnityEngine;

public class PlantSpawner : MonoBehaviour
{
    [SerializeField] private string[] tags;
    [Range(1, 5)]
    [SerializeField] private float spawnRaidus = 1;
    [Range(1, 10)]
    [SerializeField] private float density = 1;

    private ObjectPooler objectPooler;

    private void Start()
    {
        objectPooler = ObjectPooler.Instance;
    }

    public void SpawnPlant(Vector3 position, Quaternion rotation)
    {
        for (int i = 0; i < density; i++)
        {
            objectPooler.SpawnFromPool(
                tags[Random.Range(0, tags.Length)],
                transform.position + (Vector3)Random.insideUnitCircle * spawnRaidus,
                Quaternion.identity
                );
        }
    }
}
