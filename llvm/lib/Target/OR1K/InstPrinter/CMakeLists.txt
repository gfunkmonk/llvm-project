include_directories( ${CMAKE_CURRENT_BINARY_DIR}/.. ${CMAKE_CURRENT_SOURCE_DIR}/.. )

add_llvm_component_library(LLVMOR1KAsmPrinter
  OR1KInstPrinter.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  OR1K
  )

add_dependencies(LLVMOR1KAsmPrinter OR1KCommonTableGen)
