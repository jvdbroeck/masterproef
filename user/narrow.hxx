#ifndef __NARROW_HXX__
#define __NARROW_HXX__

#include <cassert>
#include <cstdint>
#include <limits>


template <typename TargetT, typename SourceT, bool T_IS_SIGNED = std::numeric_limits<TargetT>::is_signed>
struct SafeConversion
{
  static
  TargetT
  narrow(SourceT value)
  {
    assert(value >= std::numeric_limits<TargetT>::min());
    assert(value <= std::numeric_limits<TargetT>::max());
    return static_cast<TargetT>(value);
  }
};

template <typename TargetT, typename SourceT>
struct SafeConversion<TargetT, SourceT *, true>
{
  static
  TargetT
  narrow(SourceT *ptr)
  {
    return SafeConversion<TargetT, intptr_t>(reinterpret_cast<intptr_t>(ptr));
  }
};

template <typename TargetT, typename SourceT>
struct SafeConversion<TargetT, SourceT *, false>
{
  static
  TargetT
  narrow(SourceT *ptr)
  {
    return SafeConversion<TargetT, intptr_t>(reinterpret_cast<uintptr_t>(ptr));
  }
};

template <typename TargetT, typename SourceT>
TargetT
narrow(SourceT value)
{
  return SafeConversion<TargetT, SourceT>::narrow(value);
}

#endif /* __NARROW_HXX__*/