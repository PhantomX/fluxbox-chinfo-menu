FIND_PACKAGE(Gettext REQUIRED)

# Borrowed from manaworld.

# based on the CMake 2.6.3 GETTEXT_CREATE_TRANSLATIONS
# we need our own version because the upstream one contains
# a call to msgmerge (updating po files) which can't be
# disabled
MACRO(FCM_GETTEXT_CREATE_TRANSLATIONS _potFile _firstPoFileArg)
   # make it a real variable, so we can modify it here
   SET(_firstPoFile "${_firstPoFileArg}")

   SET(_gmoFiles)
   GET_FILENAME_COMPONENT(_potBasename ${_potFile} NAME_WE)
   GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)

   SET(_addToAll)
   IF(${_firstPoFile} STREQUAL "ALL")
      SET(_addToAll "ALL")
      SET(_firstPoFile)
   ENDIF(${_firstPoFile} STREQUAL "ALL")

   FOREACH (_currentPoFile ${_firstPoFile} ${ARGN})
      GET_FILENAME_COMPONENT(_absFile ${_currentPoFile} ABSOLUTE)
      GET_FILENAME_COMPONENT(_abs_PATH ${_absFile} PATH)
      GET_FILENAME_COMPONENT(_lang ${_absFile} NAME_WE)
      SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo)

      ADD_CUSTOM_COMMAND(
         OUTPUT ${_gmoFile}
         COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_absFile}
         DEPENDS ${_absPotFile} ${_absFile}
      )

      INSTALL(FILES ${_gmoFile} DESTINATION share/locale/${_lang}/LC_MESSAGES RENAME ${_potBasename}.mo)
      SET(_gmoFiles ${_gmoFiles} ${_gmoFile})

   ENDFOREACH (_currentPoFile)

   ADD_CUSTOM_TARGET(translations ${_addToAll} DEPENDS ${_gmoFiles})
ENDMACRO()

MACRO(FCM_GETTEXT_UPDATE_PO _potFile _languages)
   GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)

   ADD_CUSTOM_TARGET(
      update-pot
      COMMAND xgettext --files-from=translatable-files --from-code=utf-8 -L shell --directory=. --output=${_potFile} -d fluxbox-chinfo-menu
      )

   ADD_CUSTOM_TARGET(
      update-translatable-files
      COMMAND grep '.txt' -Irl ../bin | sort > translatable-files
      )

   FOREACH(_lang ${_languages})
      GET_FILENAME_COMPONENT(_absFile "${_lang}.po" ABSOLUTE)
      SET(_currentPoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.po)
      ADD_CUSTOM_TARGET(
         "update-translation-${_lang}"
         COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none -s ${_absFile} ${_absPotFile}
         )
      ADD_DEPENDENCIES("update-translation-${_lang}" update-pot)
      ADD_DEPENDENCIES(update-po "update-translation-${_lang}")
      ADD_DEPENDENCIES(update-pot update-translatable-files)
   ENDFOREACH()
ENDMACRO()


SET(languages)
SET(POFILES)
FILE(STRINGS LINGUAS _languages)
FOREACH(_lang ${_languages})
   STRING(REGEX REPLACE "#.*" "" _lang "${_lang}")
   IF(NOT ${_lang} STREQUAL "")
      SET(languages ${languages} ${_lang})
      SET(POFILES ${POFILES} "${_lang}.po")
   ENDIF()
ENDFOREACH()

ADD_CUSTOM_TARGET(update-po)

FCM_GETTEXT_CREATE_TRANSLATIONS(fluxbox-chinfo-menu.pot ALL ${POFILES})
FCM_GETTEXT_UPDATE_PO(fluxbox-chinfo-menu.pot "${languages}")
