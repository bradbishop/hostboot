/* IBM_PROLOG_BEGIN_TAG                                                   */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* $Source: src/import/chips/p9a/procedures/hwp/memory/p9a_omi_train_check.H $ */
/*                                                                        */
/* OpenPOWER HostBoot Project                                             */
/*                                                                        */
/* Contributors Listed Below - COPYRIGHT 2019                             */
/* [+] International Business Machines Corp.                              */
/*                                                                        */
/*                                                                        */
/* Licensed under the Apache License, Version 2.0 (the "License");        */
/* you may not use this file except in compliance with the License.       */
/* You may obtain a copy of the License at                                */
/*                                                                        */
/*     http://www.apache.org/licenses/LICENSE-2.0                         */
/*                                                                        */
/* Unless required by applicable law or agreed to in writing, software    */
/* distributed under the License is distributed on an "AS IS" BASIS,      */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        */
/* implied. See the License for the specific language governing           */
/* permissions and limitations under the License.                         */
/*                                                                        */
/* IBM_PROLOG_END_TAG                                                     */


///
/// @file p9a_omi_train_check.H
/// @brief Check the omi status
///
// *HWP HWP Owner: Andre Marin <aamarin@us.ibm.com>
// *HWP HWP Backup: Stephen Glancy <sglancy@us.ibm.com>
// *HWP Team: Memory
// *HWP Level: 3
// *HWP Consumed by: FSP:HB

#ifndef P9A_OMI_TRAIN_CHECK_H_
#define P9A_OMI_TRAIN_CHECK_H_

#include <fapi2.H>


typedef fapi2::ReturnCode (*p9a_omi_train_check_FP_t) (const fapi2::Target<fapi2::TARGET_TYPE_OMI>&);

extern "C"
{

    ///
    /// @brief Check the omi status in Axone side
    /// @param[in] i_target the OMIC target to operate on
    /// @return FAPI2_RC_SUCCESS iff ok
    ///
    fapi2::ReturnCode p9a_omi_train_check( const fapi2::Target<fapi2::TARGET_TYPE_OMI>& i_target );

}

#endif
