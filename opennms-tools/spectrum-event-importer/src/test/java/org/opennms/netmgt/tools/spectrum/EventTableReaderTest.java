/*******************************************************************************
 * This file is part of OpenNMS(R).
 *
 * Copyright (C) 2010-2012 The OpenNMS Group, Inc.
 * OpenNMS(R) is Copyright (C) 1999-2012 The OpenNMS Group, Inc.
 *
 * OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
 *
 * OpenNMS(R) is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * OpenNMS(R) is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenNMS(R).  If not, see:
 *      http://www.gnu.org/licenses/
 *
 * For more information contact:
 *     OpenNMS(R) Licensing <license@opennms.org>
 *     http://www.opennms.org/
 *     http://www.opennms.com/
 *******************************************************************************/

package org.opennms.netmgt.tools.spectrum;

import java.io.IOException;

import org.junit.Assert;

import org.junit.Before;
import org.junit.Test;
import org.opennms.core.test.MockLogAppender;
import org.springframework.core.io.FileSystemResource;

/**
 * @author jeffg
 *
 */
public class EventTableReaderTest {
    @Before
    public void setUp() {
        MockLogAppender.setupLogging();
    }
    
    @Test
    public void oneArgConstructor() throws IOException {
        @SuppressWarnings("unused")
        EventTableReader reader = new EventTableReader(new FileSystemResource("src/test/resources/sonus-traps/CsEvFormat/EventTables/ipUnityTrapSeverity"));
    }
    
    @Test
    public void readIpUnityTrapSeverityTable() throws IOException {
        EventTableReader reader = new EventTableReader(new FileSystemResource("src/test/resources/sonus-traps/CsEvFormat/EventTables/ipUnityTrapSeverity"));
        EventTable et = reader.getEventTable();
        
        Assert.assertEquals("There should exist 6 event-map entries in this EventTable file", 6, et.size());
        
        Assert.assertEquals("clear(1)", "clear", et.get(1));
        Assert.assertEquals("informational(2)", "informational", et.get(2));
        Assert.assertEquals("warning(3)", "warning", et.get(3));
        Assert.assertEquals("minor(4)", "minor", et.get(4));
        Assert.assertEquals("major(5)", "major", et.get(5));
        Assert.assertEquals("critical(6)", "critical", et.get(6));
    }
}
