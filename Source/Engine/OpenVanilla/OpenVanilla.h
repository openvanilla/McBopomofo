//
// OpenVanilla.h
//
// Copyright (c) 2007-2010 Lukhnos D. Liu
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#ifndef OpenVanilla_h
#define OpenVanilla_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVAroundFilter.h>
    #include <OpenVanilla/OVBase.h>
    #include <OpenVanilla/OVBenchmark.h>
    #include <OpenVanilla/OVCandidateService.h>
    #include <OpenVanilla/OVCINDataTable.h>
    #include <OpenVanilla/OVCINDatabaseService.h>
    #include <OpenVanilla/OVDatabaseService.h>
    #include <OpenVanilla/OVDateTimeHelper.h>
    #include <OpenVanilla/OVEventHandlingContext.h>
    #include <OpenVanilla/OVFileHelper.h>
    #include <OpenVanilla/OVFrameworkInfo.h>
    #include <OpenVanilla/OVInputMethod.h>
    #include <OpenVanilla/OVLocalization.h>    
    #include <OpenVanilla/OVKey.h>
    #include <OpenVanilla/OVKeyValueMap.h>
    #include <OpenVanilla/OVLoaderService.h>
    #include <OpenVanilla/OVModule.h>
    #include <OpenVanilla/OVModulePackage.h>
    #include <OpenVanilla/OVOutputFilter.h>
    #include <OpenVanilla/OVPathInfo.h>
    #include <OpenVanilla/OVStringHelper.h>    
    #include <OpenVanilla/OVTextBuffer.h>
    #include <OpenVanilla/OVUTF8Helper.h>
    #include <OpenVanilla/OVWildcard.h>
    
    #ifdef OV_USE_SQLITE
        #include <OpenVanilla/OVSQLiteDatabaseService.h>
        #include <OpenVanilla/OVSQLiteWrapper.h>
    #endif
#else
    #ifdef WIN32
        #include <windows.h>
    #endif
    
    #include "OVAroundFilter.h"
    #include "OVBase.h"
    #include "OVBenchmark.h"
    #include "OVCandidateService.h"
    #include "OVCINDataTable.h"
    #include "OVCINDatabaseService.h"
    #include "OVDatabaseService.h"
    #include "OVDateTimeHelper.h"
    #include "OVEventHandlingContext.h"
    #include "OVFileHelper.h"
    #include "OVFrameworkInfo.h"
    #include "OVInputMethod.h"
    #include "OVLocalization.h"
    #include "OVKey.h"
    #include "OVKeyValueMap.h"
    #include "OVLoaderService.h"
    #include "OVModule.h"
    #include "OVModulePackage.h"
    #include "OVOutputFilter.h"
    #include "OVPathInfo.h"
    #include "OVStringHelper.h"
    #include "OVTextBuffer.h"    
    #include "OVUTF8Helper.h"
    #include "OVWildcard.h"
    
    #ifdef OV_USE_SQLITE
        #include "OVSQLiteDatabaseService.h"
        #include "OVSQLiteWrapper.h"
    #endif
#endif

#endif
