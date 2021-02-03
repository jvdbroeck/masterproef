#ifndef __MEMORY_MAPPING_HXX__
#define __MEMORY_MAPPING_HXX__

//#include <iostream>

#include "FileDescriptor.hxx"

struct MemoryMapping
{
  MemoryMapping() noexcept:
    m_ptr(reinterpret_cast<void *>(MMAP_FAILURE)),
    m_length(0)
  {}

  MemoryMapping(size_t length, int prot, int flags, const FileDescriptor &fd, off_t offset = 0) noexcept:
    MemoryMapping(nullptr, length, prot, flags, fd, offset)
  {}

  MemoryMapping(void *addr, size_t length, int prot, int flags, const FileDescriptor &fd, off_t offset = 0) noexcept:
    m_ptr(::mmap(addr, length, prot, flags, fd, offset)),
    m_length(length)
  {
    /*uint32_t *buffer = (uint32_t*)m_ptr;
    std::cout << "MemoryMapping: ";
    for(int i=0; i<10; i++) {
      std::cout << buffer[i] << " ";
    }
    std::cout << std::endl;*/
  }

  MemoryMapping(const MemoryMapping &) = delete;

  MemoryMapping(MemoryMapping &&mm) noexcept:
    m_ptr(mm.m_ptr),
    m_length(mm.m_length)
  {
    mm.m_ptr = reinterpret_cast<void *>(MMAP_FAILURE);
  }

  MemoryMapping &
  operator =(const MemoryMapping &) = delete;

  MemoryMapping &
  operator =(MemoryMapping &&mm) noexcept
  {
    if (&mm != this)
    {
      m_ptr = mm.m_ptr;
      m_length = mm.m_length;
      mm.m_ptr = reinterpret_cast<void *>(MMAP_FAILURE);
    }
    return *this;
  }

  ~MemoryMapping() noexcept
  {
    if (isValid())
    {
      ::munmap(m_ptr, m_length);
    }
  }


  template <typename T>
  T *
  get()
  {
    return reinterpret_cast<T *>(m_ptr);
  }

  template <typename T>
  const T *
  get() const
  {
    return reinterpret_cast<const T *>(m_ptr);
  }

  bool
  isValid() const
  {
    return reinterpret_cast<intptr_t>(m_ptr) != MMAP_FAILURE;
  }

private:

  static constexpr intptr_t MMAP_FAILURE = -1;

  void *m_ptr;
  size_t m_length;
};

#endif /* __MEMORY_MAPPING_HXX__ */
