#ifndef __FILE_DESCRIPTOR_HXX__
#define __FILE_DESCRIPTOR_HXX__

#include <unistd.h>


struct FileDescriptor
{
  explicit
  FileDescriptor(int fd = -1):
    m_fd(fd)
  {}

  FileDescriptor(const FileDescriptor &) = delete;

  FileDescriptor(FileDescriptor &&) = default;

  FileDescriptor &
  operator =(const FileDescriptor &) = delete;

  FileDescriptor &
  operator =(FileDescriptor &&) = default;

  ~FileDescriptor()
  {
    if (isValid())
    {
      ::close(m_fd);
    }
  }


  operator int() const
  {
    return m_fd;
  }

  bool
  isValid() const
  {
    return m_fd >= 0;
  }

private:

  int m_fd;
};

#endif /* __FILE_DESCRIPTOR_HXX__ */