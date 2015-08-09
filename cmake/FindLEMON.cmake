# From http://brlcad.org/websvn/filedetails.php?repname=BRL-CAD&path=%2Fbrlcad%2Ftrunk%2Fmisc%2FCMake%2FFindLEMON.cmake&rev=48023

# - Find lemon executable and provides macros to generate custom build rules
# The module defines the following variables
#
#  LEMON_EXECUTABLE - path to the lemon program
#  LEMON_FOUND - true if the program was found
#
# If lemon is found, the module defines the macro
#  LEMON_TARGET(<Name> <LemonInput> <LemonSource> <LemonHeader>
#               [<ArgString>])
# which will create a custom rule to generate a parser. <LemonInput> is
# the path to a lemon file. <LemonSource> is the desired name for the
# generated source file. <LemonHeader> is the desired name for the
# generated header which contains the token list. Anything in the optional
# <ArgString> parameter is appended to the lemon command line.
#
# The macro defines a set of variables:
# LEMON_${Name}_DEFINED       - True if the macro ran successfully
# LEMON_${Name}_INPUT         - The input source file, an alias for <LemonInput>
# LEMON_${Name}_OUTPUT_SOURCE - The source file generated by lemon, an alias for <LemonSource>
# LEMON_${Name}_OUTPUT_HEADER - The header file generated by lemon, an alias for <LemonHeader>
# LEMON_${Name}_OUTPUTS       - All bin outputs
# LEMON_${Name}_EXTRA_ARGS    - Arguments added to the lemon command line
#
#  ====================================================================
#  Example:
#
#   find_package(LEMON)
#   LEMON_TARGET(MyParser parser.y parser.c parser.h)
#   add_executable(Foo main.cpp ${LEMON_MyParser_OUTPUTS})
#  ====================================================================
#
#=============================================================================
#                 F I N D L E M O N . C M A K E
#
# Originally based off of FindBISON.cmake from Kitware's CMake distribution
#
# Copyright 2010 United States Government as represented by
#                the U.S. Army Research Laboratory.
# Copyright 2009 Kitware, Inc.
# Copyright 2006 Tristan Carel
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * The names of the authors may not be used to endorse or promote
#   products derived from this software without specific prior written
#   permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

FIND_PROGRAM(LEMON_EXECUTABLE lemon DOC "path to the lemon executable")
MARK_AS_ADVANCED(LEMON_EXECUTABLE)

IF(LEMON_EXECUTABLE AND NOT LEMON_TEMPLATE)
    get_filename_component(lemon_path ${LEMON_EXECUTABLE} PATH)
    IF(lemon_path)
        SET(LEMON_TEMPLATE "")
        IF(EXISTS ${lemon_path}/lempar.c)
            SET(LEMON_TEMPLATE "${lemon_path}/lempar.c")
        ENDIF(EXISTS ${lemon_path}/lempar.c)
        IF(EXISTS /usr/share/lemon/lempar.c)
            SET(LEMON_TEMPLATE "/usr/share/lemon/lempar.c")
        ENDIF(EXISTS /usr/share/lemon/lempar.c)
    ENDIF(lemon_path)
ENDIF(LEMON_EXECUTABLE AND NOT LEMON_TEMPLATE)
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LEMON DEFAULT_MSG LEMON_EXECUTABLE LEMON_TEMPLATE)
MARK_AS_ADVANCED(LEMON_TEMPLATE)

#============================================================
# LEMON_TARGET (public macro)
#============================================================
#
MACRO(LEMON_TARGET Name LemonInput LemonSource LemonHeader)
        IF(NOT ${ARGC} EQUAL 4 AND NOT ${ARGC} EQUAL 5)
                MESSAGE(SEND_ERROR "Usage")
        ELSE()
                GET_FILENAME_COMPONENT(LemonInputFull ${LemonInput}  ABSOLUTE)
                GET_FILENAME_COMPONENT(LemonSourceFull ${LemonSource} ABSOLUTE)
                GET_FILENAME_COMPONENT(LemonHeaderFull ${LemonHeader} ABSOLUTE)

                IF(NOT ${LemonInput} STREQUAL ${LemonInputFull})
                        SET(LEMON_${Name}_INPUT "${CMAKE_CURRENT_BINARY_DIR}/${LemonInput}")
                ELSE(NOT ${LemonInput} STREQUAL ${LemonInputFull})
                        SET(LEMON_${Name}_INPUT "${LemonInput}")
                ENDIF(NOT ${LemonInput} STREQUAL ${LemonInputFull})

                IF(NOT ${LemonSource} STREQUAL ${LemonSourceFull})
                        SET(LEMON_${Name}_OUTPUT_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/${LemonSource}")
                ELSE(NOT ${LemonSource} STREQUAL ${LemonSourceFull})
                        SET(LEMON_${Name}_OUTPUT_SOURCE "${LemonSource}")
                ENDIF(NOT ${LemonSource} STREQUAL ${LemonSourceFull})

                IF(NOT ${LemonHeader} STREQUAL ${LemonHeaderFull})
                        SET(LEMON_${Name}_OUTPUT_HEADER "${CMAKE_CURRENT_BINARY_DIR}/${LemonHeader}")
                ELSE(NOT ${LemonHeader} STREQUAL ${LemonHeaderFull})
                        SET(LEMON_${Name}_OUTPUT_HEADER "${LemonHeader}")
                ENDIF(NOT ${LemonHeader} STREQUAL ${LemonHeaderFull})

                SET(LEMON_${Name}_EXTRA_ARGS    "${ARGV4}")

                # get input name minus path
                GET_FILENAME_COMPONENT(INPUT_NAME "${LemonInput}" NAME)
                SET(LEMON_BIN_INPUT ${CMAKE_CURRENT_BINARY_DIR}/${INPUT_NAME})

                # names of lemon output files will be based on the name of the input file
                STRING(REGEX REPLACE "^(.*)(\\.[^.]*)$" "\\1.c"   LEMON_GEN_SOURCE "${INPUT_NAME}")
                STRING(REGEX REPLACE "^(.*)(\\.[^.]*)$" "\\1.h"   LEMON_GEN_HEADER "${INPUT_NAME}")
                STRING(REGEX REPLACE "^(.*)(\\.[^.]*)$" "\\1.out" LEMON_GEN_OUT    "${INPUT_NAME}")

                SET(LEMON_${Name}_OUTPUTS ${LemonSource} ${LemonHeader} ${LEMON_GEN_OUT})

                # copy input to bin directory, run lemon, and rename generated outputs
                ADD_CUSTOM_COMMAND(
                        OUTPUT ${LEMON_${Name}_OUTPUTS}
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${LemonInput} ${LEMON_BIN_INPUT}
                        COMMAND ${LEMON_EXECUTABLE} ${INPUT_NAME} ${LEMON_${Name}_EXTRA_ARGS}
                        COMMAND ${CMAKE_COMMAND} -E rename ${LEMON_GEN_SOURCE} ${LemonSource}
                        COMMAND ${CMAKE_COMMAND} -E rename ${LEMON_GEN_HEADER} ${LemonHeader}
                        DEPENDS ${LemonInput} ${LEMON_EXECUTABLE_TARGET}
                        COMMENT "[LEMON][${Name}] Building parser with ${LEMON_EXECUTABLE}"
                )

                # macro ran successfully
                SET(LEMON_${Name}_DEFINED TRUE)
        ENDIF(NOT ${ARGC} EQUAL 4 AND NOT ${ARGC} EQUAL 5)
ENDMACRO(LEMON_TARGET)
#
#============================================================
# FindLEMON.cmak