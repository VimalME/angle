//
// Copyright 2017 The ANGLE Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// SizedMRUCache.h: A hashing map that stores blobs of sized, untyped data.

#ifndef LIBANGLE_SIZED_MRU_CACHE_H_
#define LIBANGLE_SIZED_MRU_CACHE_H_

#include <anglebase/containers/mru_cache.h>
#include "common/third_party/murmurhash/MurmurHash3.h"

namespace angle
{

template <typename Key, typename Value>
class SizedMRUCache final : angle::NonCopyable
{
  public:
    SizedMRUCache(size_t maximumTotalSize)
        : mMaximumTotalSize(maximumTotalSize),
          mCurrentSize(0),
          mStore(SizedMRUCacheStore::NO_AUTO_EVICT)
    {
    }

    void put(const Key &key, Value &&value, size_t size)
    {
        ASSERT(size <= mMaximumTotalSize);

        // Check for existing key.
        eraseByKey(key);

        mStore.Put(key, ValueAndSize(std::move(value), size));
        mCurrentSize += size;

        while (mCurrentSize > mMaximumTotalSize)
        {
            ASSERT(!mStore.empty());
            auto iter = mStore.rbegin();
            mCurrentSize -= iter->second.size;
            mStore.Erase(iter);
        }
    }

    bool get(const Key &key, const Value **valueOut)
    {
        const auto &iter = mStore.Get(key);
        if (iter == mStore.end())
        {
            return false;
        }
        *valueOut = &iter->second.value;
        return true;
    }

    bool empty() const { return mStore.empty(); }

    void clear()
    {
        mStore.Clear();
        mCurrentSize = 0;
    }

    bool eraseByKey(const Key &key)
    {
        // Check for existing key.
        auto existing = mStore.Peek(key);
        if (existing != mStore.end())
        {
            mCurrentSize -= existing->second.size;
            mStore.Erase(existing);
            return true;
        }

        return false;
    }

    size_t size() const { return mCurrentSize; }

  private:
    struct ValueAndSize
    {
        ValueAndSize() : value(), size(0) {}
        ValueAndSize(Value &&value, size_t size) : value(std::move(value)), size(size) {}
        ValueAndSize(ValueAndSize &&other) : ValueAndSize() { *this = std::move(other); }
        ValueAndSize &operator=(ValueAndSize &&other)
        {
            std::swap(value, other.value);
            std::swap(size, other.size);
            return *this;
        }

        Value value;
        size_t size;
    };

    using SizedMRUCacheStore = base::HashingMRUCache<Key, ValueAndSize>;

    size_t mMaximumTotalSize;
    size_t mCurrentSize;
    SizedMRUCacheStore mStore;
};

// Helper function used in a few places.
template <typename T>
void TrimCache(size_t maxStates, size_t gcLimit, const char *name, T *cache)
{
    const size_t kGarbageCollectionLimit = maxStates / 2 + gcLimit;

    if (cache->size() >= kGarbageCollectionLimit)
    {
        WARN() << "Overflowed the " << name << " cache limit of " << (maxStates / 2)
               << " elements, removing the least recently used to make room.";
        cache->ShrinkToSize(maxStates / 2);
    }
}

template <typename T>
std::size_t ComputeGenericHash(const T &key)
{
    static const unsigned int seed = 0xABCDEF98;

    std::size_t hash = 0;
    MurmurHash3_x86_32(&key, sizeof(key), seed, &hash);
    return hash;
}

}  // namespace angle
#endif  // LIBANGLE_SIZED_MRU_CACHE_H_
