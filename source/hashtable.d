module hashtable;

///simple nogc implementation of a hash table
struct HashTable(T, int noOfEntries, int noOfBuckets)
{
	private alias E = Entry!(T);
	private E[noOfEntries] entries = E(T.init, noNextEntry);
	private size_t[noOfBuckets] buckets = noNextEntry;

	private size_t noOfFreeEntries = noOfEntries;

	private enum noNextEntry = entries.length;

	///reset the hash table to its initial empty state
	void clear() @safe @nogc
	{
		buckets[] = noNextEntry;
		foreach (ref E entry; entries)
		{
			entry = E(T.init, noNextEntry);
		}
		noOfFreeEntries = noOfEntries;
	}

	///get the contents of a specific bucket of the hash table in the form of a range
	BucketContents!(T, noOfEntries) contents(size_t bucket) @safe @nogc
	{
		BucketContents!(T, noOfEntries) result;

		if (buckets[bucket] != noNextEntry)
		{
			E entry = entries[buckets[bucket]];

			while (true)
			{
				result.contents[result.size] = entry.value;
				++result.size;

				if (entry.next != noNextEntry)
				{
					entry = entries[entry.next];
				}
				else
					break;
			}
		}
		return result;
	}

	///add an entry to the hash table
	void add(in T value, in size_t bucket) @safe @nogc
	{
		assert(noOfFreeEntries > 0);
		immutable entryIndex = noOfEntries - noOfFreeEntries;
		--noOfFreeEntries;

		entries[entryIndex] = E(value, noNextEntry);

		if (buckets[bucket] == noNextEntry)
		{
			buckets[bucket] = entryIndex;
		}
		else
		{
			E entry = entries[buckets[bucket]];
			size_t temp;
			while (entry.next != noNextEntry) //if something goes wrong and we get circular references, we loop forever...
			{
				temp = entry.next;
				entry = entries[temp];
			}
			entries[temp].next = entryIndex;
		}
	}
}

private struct Entry(T)
{
	T value;
	size_t next;
}

private struct BucketContents(T, size_t length)
{
	T[length] contents;
	size_t size;
	private size_t index;

	bool empty() @safe @nogc
	{
		return index >= size;
	}

	T front() @safe @nogc
	{
		return contents[index];
	}

	void popFront() @safe @nogc
	{
		++index;
	}
}

@safe @nogc unittest
{
	HashTable!(int, 6, 2) table;

	table.add(69, 1);
	table.add(420, 1);

	int i = 0;
	foreach (a; table.contents(1))
	{
		if (i == 0)
		{
			assert(a == 69);
		}
		else
		{
			assert(i == 1);
			assert(a == 420);
		}
		++i;
	}

	table.clear();
	immutable HashTable!(int, 6, 2) itable;
	assert(table == itable);
}
