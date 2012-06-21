//
// This file is part of the OpenNMS(R) Application.
//
// OpenNMS(R) is Copyright (C) 2006 The OpenNMS Group, Inc.  All rights reserved.
// OpenNMS(R) is a derivative work, containing both original code, included code and modified
// code that was published under the GNU General Public License. Copyrights for modified
// and included code are below.
//
// OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
//
// Original code base Copyright (C) 1999-2001 Oculan Corp.  All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//
// For more information contact:
// OpenNMS Licensing       <license@opennms.org>
//     http://www.opennms.org/
//     http://www.opennms.com/
//
package org.opennms.netmgt.invd.exceptions;

import org.opennms.core.utils.ThreadCategory;
import org.opennms.netmgt.invd.InventoryScanner;

public class InventoryException extends Exception {
	private static final long serialVersionUID = 1470798584271528804L;
	private int m_errorCode = InventoryScanner.SCAN_FAILED;

    public InventoryException() {
        super();
    }

    public InventoryException(String message) {
        super(message);
    }

    public InventoryException(String message, Throwable cause) {
        super(message, cause);
    }

    public InventoryException(Throwable cause) {
        super(cause);
    }

    public int reportError() {
        logError();
    	return getErrorCode();
    }

    protected void logError() {
        if (getCause() == null) {
            log().error(getMessage());
    	} else {
            log().error(getMessage(), getCause());
    	}
    }

    protected ThreadCategory log() {
        return ThreadCategory.getInstance(getClass());
    }

    void setErrorCode(int errorCode) {
        m_errorCode = errorCode;
    }

    int getErrorCode() {
        return m_errorCode;
    }
}