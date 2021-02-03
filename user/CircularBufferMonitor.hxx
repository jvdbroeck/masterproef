#ifndef __CIRCULAR_BUFFER_MONITOR_HXX__
#define __CIRCULAR_BUFFER_MONITOR_HXX__

#include <cassert>
#include <condition_variable>
#include <cstdint>
#include <memory>
#include <mutex>
#include <thread>



// TODO:  werken met condition_variable zodat we de consumer kunnen laten wachten op de producer

struct CircularBufferMonitor
{
  using slot_t = int8_t;


  CircularBufferMonitor(slot_t slots);

  CircularBufferMonitor(const CircularBufferMonitor &) = delete;

  CircularBufferMonitor(CircularBufferMonitor &&) = delete;

  CircularBufferMonitor &
  operator =(const CircularBufferMonitor &) = delete;

  CircularBufferMonitor &
  operator =(CircularBufferMonitor &&) = delete;

  ~CircularBufferMonitor() = default;


  void
  confirmConsumed(slot_t slot);

  void
  confirmProduced(slot_t slot, uint32_t nbytes);

  slot_t
  getNextFreeSlot();

  slot_t
  getNextFullSlot(uint32_t &nbytesptr);


private:

  using guard = std::lock_guard<std::mutex>;


  std::mutex m_mutex;
  std::condition_variable m_condition;
  slot_t m_slots;
  slot_t m_start;
  slot_t m_end;
  bool m_start_mirror;
  bool m_end_mirror;
  uint32_t m_last_written_bytecount;


  void
  increment(slot_t &slot, bool &mirror);

  bool
  isEmpty() const;

  bool
  isFull() const;
};


CircularBufferMonitor::CircularBufferMonitor(slot_t slots):
  m_mutex(),
  m_slots(slots),
  m_start(0),
  m_end(0),
  m_start_mirror(false),
  m_end_mirror(false),
  m_last_written_bytecount(0)
{
}


void
CircularBufferMonitor::confirmConsumed(slot_t slot)
{
  guard g(m_mutex);
  assert(!isEmpty());
  assert(m_start == slot);
  increment(m_start, m_start_mirror);
}

void
CircularBufferMonitor::confirmProduced(slot_t slot, uint32_t nbytes)
{
  /*
   * Since we use getNextFreeSlot before production the producer is aware that the buffer is full. Hence it should not
   * try to write more.
   *
   * Solution to allow overwriting:
   * if (isFull(cb))
   * {
   *   increment(m_start, m_start_mirror);
   * }
   */
  guard g(m_mutex);
  assert(!isFull());
  assert(m_end == slot);
  m_last_written_bytecount = nbytes;
  increment(m_end, m_end_mirror);

  // Finally, notify waiting threads (getNextFullSlot)
  m_condition.notify_all();
}

CircularBufferMonitor::slot_t
CircularBufferMonitor::getNextFreeSlot()
{
  // Locking is required because isFull and isEmpty check both start/end and mirror bits, which are updated separately!
  guard g(m_mutex);
  return isFull() ? static_cast<slot_t>(-1) : m_end;
}

CircularBufferMonitor::slot_t
CircularBufferMonitor::getNextFullSlot(uint32_t &nbytesptr)
{
  // Locking is required; see getNextFreeSlot
  std::unique_lock<std::mutex> lk(m_mutex);

  // Wait for new data to be put in the buffer.
  // This thread is notified by confirmProduced.
  m_condition.wait(lk, [&]{return !isEmpty();});

  // New data is ready.
  nbytesptr = (m_start == (m_end-1)) ? m_last_written_bytecount : 0;

  return isEmpty() ? static_cast<slot_t>(-1) : m_start;
}

void
CircularBufferMonitor::increment(slot_t &slot, bool &mirror)
{
  if (++slot == m_slots)
  {
    mirror ^= 1;
    slot = 0;
  }
}

bool
CircularBufferMonitor::isEmpty() const
{
  return m_start == m_end && m_start_mirror == m_end_mirror;
}

bool
CircularBufferMonitor::isFull() const
{
  return m_start == m_end && m_start_mirror != m_end_mirror;
}

#endif /* __CIRCULAR_BUFFER_MONITOR_HXX__ */
