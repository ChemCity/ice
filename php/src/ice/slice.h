// **********************************************************************
//
// Copyright (c) 2003
// ZeroC, Inc.
// Billerica, MA, USA
//
// All Rights Reserved.
//
// Ice is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License version 2 as published by
// the Free Software Foundation.
//
// **********************************************************************

#ifndef ICE_PHP_SLICE_H
#define ICE_PHP_SLICE_H

extern "C"
{
#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
}

#include <Slice/Parser.h>

bool Slice_init(TSRMLS_DC);
Slice::UnitPtr Slice_getUnit(TSRMLS_DC);
bool Slice_shutdown(TSRMLS_DC);
zend_class_entry* Slice_get_class(const std::string&);
bool Slice_is_native_key(const Slice::TypePtr&);

#endif
